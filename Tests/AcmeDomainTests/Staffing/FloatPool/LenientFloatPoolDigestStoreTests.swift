@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLenientFloatPoolDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LenientFloatPoolDigestStore = Staffing.newMemoryLenientFloatPoolDigestStore()
        let item = Staffing.newLenientFloatPoolDigest("code-61", name: "name-854")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
