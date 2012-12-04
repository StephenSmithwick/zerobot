$(document).ready(function () {

    $('#create-another-link').live('click', function () {
        $.removeCookie('project_data');
        $.removeCookie('project_id');
        $.removeCookie('project_token');
        window.refresh();
    });

    var getSuccess = function(response) {
        if (response.status === 'CREATE_COMPLETE') {
            $('#loading-image').remove();
            $('#please-wait').remove();
            $('#waiting .page-container').append('<h2>Your environment is ready for action</h2><h1><a href="' + response.output.value + '" target="_blank">' + response.output.value + '</a></h1>');
            $('#waiting .page-container').append('<p>Done with this environment? <a id="create-another-link" href="">Create another</a></p>');
            return;
        } else {
          setTimeout(function () {
            $.ajax({
              type: 'GET',
              url: '/projects/' + response.id,
              contentType: "application/json",
              success: getSuccess
            });
         }, 50000);
        }
    };

    var inifiniteCheck = function (projectId) {
        $.ajax({
            type: 'GET',
            url: '/projects/' + projectId,
            contentType: "application/json",
            success:  getSuccess
        });

        $('#please-wait').append('<div id="loading-image"><img src="/assets/ajax-loading.gif" alt="Loading..." /></div>');
    };

    $.scrollingWizard({
        steps: [{
            id: '#page1',
            validation: function () {
                var text = $('#application-name').val().replace(/[^a-z0-9_\s]/gi, '').replace(/[\s]/g, '-');

                if (text === '') {
                    return null;
                }

                $('b.url').html(text);

                $('#summary-application-name').text(text);

                $.cookie('project_token', $('#application-token').val(), {path: '/', expires: 365});
                return text;
            },
            focus: function () {
                $('#application-name').focus();
            }
        },
        {
            id: '#aws-details',
            validation: function () {

                var accessKey = $('#aws-access-key-id').val();
                var secretKey = $('#aws-secret-access-key').val();
                var privateKey = $('#aws-private-key').val();

                if (accessKey === '' || secretKey === '' || privateKey === '') {
                  return null;
                }
                $('#summary-aws-account').text(accessKey + ' ' + secretKey + ' ' + privateKey);
                return true;
            }
        },
        {
            id: '#summary',
            validation: function () {
                return true;
            },
            finish: true
        },{
            id: '#waiting',
            validation: function () {
                return true;
            }
        },{
            id: '#region',
            validation: function () {
                $('#summary-aws-region').text($('#aws-region').val());
                return $('#aws-region').val();
            }
        }],
        finished: function () {
            var applicationName = $('#application-name').val().replace(/[^a-z0-9_\s]/gi, '').replace(/[\s]/g, '-');
            var data = {project: {
                name: applicationName,
                token: $('#application-token').val(),
                github_account: $('#github-account').val(),
                github_project: applicationName,
                region: $('#aws-region').val(),
                aws_access_key: $("#aws-access-key-id").val(),
                aws_secret_access_key: $("#aws-secret-access-key").val(),
                aws_key_name: $("#aws-private-key").val()
            }};

            $.cookie('project_data', JSON.stringify(data), {expires: 365});

            var postSuccess = function(response) {
                $.cookie('project_id', response.id, {expires: 365});
                inifiniteCheck(response.id);
            };

            $.ajax({
                type: 'POST',
                url: '/projects',
                contentType: "application/json",
                data: JSON.stringify(data),
               success: postSuccess
            });
        }
    });
});
