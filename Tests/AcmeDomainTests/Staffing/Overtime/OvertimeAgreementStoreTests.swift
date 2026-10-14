@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeAgreementStore = Staffing.newMemoryOvertimeAgreementStore()
        let item = Staffing.newOvertimeAgreement("code-668", title: "title-565")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
