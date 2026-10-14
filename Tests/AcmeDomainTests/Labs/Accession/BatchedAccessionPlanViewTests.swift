@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedAccessionPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedAccessionPlan("code-771", title: "title-890")
        let view = Labs.toBatchedAccessionPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedAccessionPlanViews([item, item]).count == 2)
    }
}
