@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedSpecimenQuota("code-310", label: "label-298")
        let view = Labs.toCappedSpecimenQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedSpecimenQuotaViews([item, item]).count == 2)
    }
}
