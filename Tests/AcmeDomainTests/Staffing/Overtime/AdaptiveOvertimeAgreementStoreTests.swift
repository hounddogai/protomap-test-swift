@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAdaptiveOvertimeAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AdaptiveOvertimeAgreementStore = Staffing.newMemoryAdaptiveOvertimeAgreementStore()
        let item = Staffing.newAdaptiveOvertimeAgreement("code-37", label: "label-542")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
