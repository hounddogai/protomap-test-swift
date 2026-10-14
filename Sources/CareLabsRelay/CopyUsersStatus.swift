import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyUsersStatus keeps of each BrowseUsers response.
struct CopyUsersStatusRecord {
    var status: String
    var nextPageToken: String
    var correlationID: String
}

/// Where CopyUsersStatus hands each record.
protocol CopyUsersStatusDestination {
    func push(_ rec: CopyUsersStatusRecord) async throws
}

/// Sends records to acme.surveys.v1.SurveyService.
struct CopyUsersStatusSurvey: CopyUsersStatusDestination {
    let client: Acme_Surveys_V1_SurveyService.Client<MeshTransport>

    func push(_ rec: CopyUsersStatusRecord) async throws {
        _ = try await client.getSurvey(.with {
            $0.surveyID = rec.status
        })
    }
}

/// Sends records to acme.patients.v1.PatientValidationService.
struct CopyUsersStatusPatientValidation: CopyUsersStatusDestination {
    let client: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>

    func push(_ rec: CopyUsersStatusRecord) async throws {
        _ = try await client.explainPatientDecision(.with {
            $0.patientID = rec.status
            $0.patient.patientID = rec.nextPageToken
            $0.details.locale = rec.correlationID
        })
    }
}

/// Reads acme.identity.v1.UserQueryService/BrowseUsers and hands what it keeps to the sink of its kind.
enum CopyUsersStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)
        let response = try await origin.browseUsers(.with { $0.orderBy = "live-copy-users-status" })
        let rec = CopyUsersStatusRecord(
            status: Kit.Text.normalize(response.result.status),
            nextPageToken: response.pageInfo.nextPageToken,
            correlationID: response.result.correlationID
        )
        let sinks: [any CopyUsersStatusDestination] = [
            CopyUsersStatusSurvey(client: Acme_Surveys_V1_SurveyService.Client(wrapping: mesh)),
            CopyUsersStatusPatientValidation(client: Acme_Patients_V1_PatientValidationService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.push(rec)
        }
    }
}
