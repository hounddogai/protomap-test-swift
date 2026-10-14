@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionPlan("code-13", title: "title-985")
        let view = Labs.toAccessionPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionPlanViews([item, item]).count == 2)
    }
}
