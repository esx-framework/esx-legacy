(() => {

	let ESXWrapper = {};
	ESXWrapper.MessageSize = 1024;
	ESXWrapper.messageId = 0;

	window.SendMessage = function (namespace, type, msg) {

		ESXWrapper.messageId = (ESXWrapper.messageId < 65535) ? ESXWrapper.messageId + 1 : 0;
		const str = JSON.stringify(msg);

		for (let i = 0; i < str.length; i++) {

			let count = 0;
			let chunk = '';

			while (count < ESXWrapper.MessageSize && i < str.length) {

				chunk += str[i];

				count++;
				i++;
			}

			i--;

			const data = {
				__type: type,
				id: ESXWrapper.messageId,
				chunk: chunk
			}

			if (i == str.length - 1)
				data.end = true;

			$.post('https://' + namespace + '/__chunk', JSON.stringify(data));

		}

	}

})()
