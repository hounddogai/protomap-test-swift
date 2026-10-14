@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeDigestStore = Staffing.newMemoryOvertimeDigestStore()
        let item = Staffing.newOvertimeDigest("code-393", title: "title-884")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
