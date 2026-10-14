@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingProgramBatch("code-223", name: "name-71")
        let view = CareManagement.toRollingProgramBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingProgramBatchViews([item, item]).count == 2)
    }
}
