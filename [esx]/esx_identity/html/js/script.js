$(function() {
	$.post('https://esx_identity/ready', JSON.stringify({}));

	window.addEventListener('message', function(event) {
		if (event.data.type == "enableui") {
			document.body.style.display = event.data.enable ? "block" : "none";
		}
	});
	
	$("#register").submit(function(event) {
		event.preventDefault(); // Prevent form from submitting
		
		// Verify date
		var date = $("#dateofbirth").val();
		var dateCheck = new Date($("#dateofbirth").val());

		if (dateCheck == "Invalid Date") {
			date == "invalid";
		}
		else {
			const ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(dateCheck)
			const mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(dateCheck)
			const da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(dateCheck)
			
			var formattedDate = `${da}/${mo}/${ye}`;

			$.post('https://esx_identity/register', JSON.stringify({
				firstname: $("#firstname").val(),
				lastname: $("#lastname").val(),
				dateofbirth: formattedDate,
				sex: $("input[type='radio'][name='sex']:checked").val(),
				height: $("#height").val()
			}));
		}
	});
});
