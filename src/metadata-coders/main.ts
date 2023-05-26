import { Command } from 'commander';
import { AgreementMetadataCoder } from './AgreementMetadataCoder';
import { CertificateMetadataCoder } from './CertificateMetadataCoder';
import { ClaimDataCoder } from './ClaimDataCoder';

const program = new Command();

program
  .name('metadata-coder')
  .description('CLI tool to encode and decode metadata')
  .version('1.0.0');

const agreementCommand = program.command('agreement');
agreementCommand.command('encode')
  .description('Encodes agreement metadata')
  .argument('<json>', 'agreement metadata JSON')
  .action(json => {
    console.log(AgreementMetadataCoder.encode(JSON.parse(json)));
  });
agreementCommand.command('decode')
  .description('Decodes agreement metadata')
  .argument('<encoded_metadata>', 'encoded agreement metadata string')
  .action(encoded => {
    console.log(AgreementMetadataCoder.decode(encoded));
  });

const certificateCommand = program.command('certificate');
certificateCommand.command('encode')
  .description('Encodes certificate metadata')
  .argument('<json>', 'certificate metadata JSON')
  .action(json => {
    console.log(CertificateMetadataCoder.encode(JSON.parse(json)));
  });
  certificateCommand.command('decode')
  .description('Decodes certificate metadata')
  .argument('<encoded_metadata>', 'encoded certificate metadata string')
  .action(encoded => {
    console.log(CertificateMetadataCoder.decode(encoded));
  });


const claimDataCommand = program.command('claim-data');
claimDataCommand.command('encode')
  .description('Encodes claim data')
  .argument('<json>', 'claim data JSON')
  .action(json => {
    console.log(ClaimDataCoder.encode(JSON.parse(json)));
  });
claimDataCommand.command('decode')
  .description('Decodes claim data')
  .argument('<encoded_metadata>', 'encoded claim data string')
  .action(encoded => {
    console.log(ClaimDataCoder.decode(encoded));
  });

program.parse();
