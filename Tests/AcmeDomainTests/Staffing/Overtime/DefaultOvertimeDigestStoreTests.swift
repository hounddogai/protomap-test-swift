@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryDefaultOvertimeDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.DefaultOvertimeDigestStore = Staffing.newMemoryDefaultOvertimeDigestStore()
        let item = Staffing.newDefaultOvertimeDigest("code-545", name: "name-374")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
