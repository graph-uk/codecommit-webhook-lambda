const aws = require('aws-sdk');
const https = require('https');

const config = require('./config.json');
const codecommit = new aws.CodeCommit();

const sendPushNotification = (url, branches) => {
	const path = `/git/notifyCommit?url=${url}&branches=${branches.join(',')}`;

	return new Promise((resolve, reject) => {
		https.get(`${config.jenkinsUrl}${path}`, res => {
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
	const data = JSON.parse(event.Records[0].Sns.Message).Records[0];
	const repositoryName = data.eventSourceARN.split(':').pop();
	const branches = data.codecommit.references.map(r => r.ref);

	return codecommit.getRepository({repositoryName})
		.promise()
		.then(data => data.repositoryMetadata.cloneUrlSsh)
		.then(url => sendPushNotification(url, branches))
		.catch(console.error);
};
