@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramWindow("code-51", name: "name-143")
        let view = CareManagement.toProgramWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramWindowViews([item, item]).count == 2)
    }
}
