import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf
import Logging
import SwiftProtobuf

@main
enum CareImporter {
    static func main() async throws {
        let settings = Settings()
        let logger = Logger(label: "acme.careimporter")
        try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .dns(host: settings.meshHost, port: try settings.port(settings.meshPort)),
                transportSecurity: .plaintext
            ),
            interceptors: [MeshCredentials(settings: settings, token: settings.token)]
        ) { mesh in
            let context = Acme_Common_V1_RequestContext.with {
                $0.tenantID = settings.tenant
                $0.actor.serviceAccount = true
                $0.actor.userID = "care-operations"
                $0.locale = "en"
            }
            let metadata: Metadata = [
                "authorization": .string("Bearer " + settings.token), "x-tenant-id": .string(settings.tenant),
            ]
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard arguments.count == 2 else {
                throw RPCError(code: .invalidArgument, message: "Usage: care-import SERVICE FILE.jsonl")
            }
            let contents = try String(contentsOfFile: arguments[1], encoding: .utf8)
            switch arguments[0] {
            case "acme.careplans.v1.CarePlanService":
                let client = Acme_Careplans_V1_CarePlanService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Careplans_V1_BatchCreateCarePlansRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.batchCreateCarePlans(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.patientapp.v1.CareInboxIntegrationService":
                let client = Acme_Patientapp_V1_CareInboxIntegrationService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Patientapp_V1_IngestCareInboxEventsRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.ingestCareInboxEvents(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.patientapp.v1.PatientHomeGatewayService":
                let client = Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Patientapp_V1_UploadPatientHomeAttachmentsRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.uploadPatientHomeAttachments(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.patientapp.v1.PatientHomeIntegrationService":
                let client = Acme_Patientapp_V1_PatientHomeIntegrationService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Patientapp_V1_IngestPatientHomeEventsRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.ingestPatientHomeEvents(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.patientapp.v1.PatientHomeService":
                let client = Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Patientapp_V1_BatchCreatePatientHomesRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.batchCreatePatientHomes(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.patients.v1.AllergyImportService":
                let client = Acme_Patients_V1_AllergyImportService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Patients_V1_ImportAllergiesRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.importAllergies(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.patients.v1.PatientService":
                let client = Acme_Patients_V1_PatientService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Patients_V1_BatchCreatePatientsRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.batchCreatePatients(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.prescriptions.v1.PrescriptionService":
                let client = Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.batchCreatePrescriptions(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.prescriptions.v1.RefillImportService":
                let client = Acme_Prescriptions_V1_RefillImportService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Prescriptions_V1_ImportRefillsRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.importRefills(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            case "acme.telehealth.v1.VideoVisitService":
                let client = Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh)
                let messages = try contents.split(separator: "\n").map { line in
                    var message = try Acme_Telehealth_V1_BatchCreateVideoVisitsRequest(jsonString: String(line))
                    message.context = context
                    return message
                }
                let response = try await client.batchCreateVideoVisits(metadata: metadata) { writer in
                    for message in messages { try await writer.write(message) }
                }
                let renderedResponse = try response.jsonString()
                logger.info("Import complete", metadata: ["response": .string(renderedResponse)])
            default:
                throw RPCError(code: .notFound, message: "Unknown import service")
            }
        }
    }
}
