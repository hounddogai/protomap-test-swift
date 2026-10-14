@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryTieredShiftDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.TieredShiftDigestStore = Staffing.newMemoryTieredShiftDigestStore()
        let item = Staffing.newTieredShiftDigest("code-485", title: "title-349")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
