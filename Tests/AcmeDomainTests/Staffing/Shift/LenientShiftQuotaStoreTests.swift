@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLenientShiftQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LenientShiftQuotaStore = Staffing.newMemoryLenientShiftQuotaStore()
        let item = Staffing.newLenientShiftQuota("code-853", label: "label-183")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
