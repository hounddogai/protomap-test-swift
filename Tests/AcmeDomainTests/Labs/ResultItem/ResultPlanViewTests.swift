@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultPlan("code-447", name: "name-740")
        let view = Labs.toResultPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultPlanViews([item, item]).count == 2)
    }
}
