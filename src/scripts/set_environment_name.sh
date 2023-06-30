 echo 'export ENVIRONMENT_NAME="<<parameters.environment>>"' >> $BASH_ENV
    source $BASH_ENV
    echo "Using displayName: $ENVIRONMENT_NAME"