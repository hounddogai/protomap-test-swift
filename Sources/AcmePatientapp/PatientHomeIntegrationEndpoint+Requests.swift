import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest {
    static func forPatientHomeIntegrationEndpointDisconnectPatientHomeSource1(
        _ input: Acme_Patientapp_V1_DisconnectPatientHomeSourceRequest
    ) -> Self {
        Acme_Patientapp_V1_SignalPatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
            }
            $0.reason = input.reason
        }
    }
}
