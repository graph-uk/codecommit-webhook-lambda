const aws = require('aws-sdk');
const https = require('https');

const config = require('./config.json');
const codecommit = new aws.CodeCommit();

const sendPushNotification = (repositoryName, url, branches) => {
	const path = `/git/notifyCommit?url=${url}&branches=${branches.join(',')}`;

	console.log(repositoryName, url, branches);

	return new Promise((resolve, reject) => {
		https.get(`${config.jenkinsUrl}${path}`, res => {
			res.on("data", data => console.log(`res: ${data}`));

			if (res.statusCode === 200) {
				resolve();
			} else {
				reject();
			}

			res.resume();
		}).on('error', reject);
	});
}

exports.handler = event => {
	const data = event.Records[0];
	const repositoryName = data.eventSourceARN.split(':').pop();
	const branches = data.codecommit.references.map(r => r.ref);

	return codecommit.getRepository({repositoryName})
		.promise()
		.then(data => data.repositoryMetadata.cloneUrlSsh)
		.then(url => sendPushNotification(repositoryName, url, branches))
		.catch(console.error);
};
