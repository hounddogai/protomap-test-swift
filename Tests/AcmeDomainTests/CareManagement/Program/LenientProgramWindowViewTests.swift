@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientProgramWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientProgramWindow("code-584", name: "name-192")
        let view = CareManagement.toLenientProgramWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientProgramWindowViews([item, item]).count == 2)
    }
}
