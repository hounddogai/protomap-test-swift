@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryManualOvertimeDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ManualOvertimeDigestStore = Staffing.newMemoryManualOvertimeDigestStore()
        let item = Staffing.newManualOvertimeDigest("code-513", name: "name-222")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
