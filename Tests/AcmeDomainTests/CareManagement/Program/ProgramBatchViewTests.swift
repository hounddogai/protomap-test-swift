@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramBatch("code-640", label: "label-55")
        let view = CareManagement.toProgramBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramBatchViews([item, item]).count == 2)
    }
}
