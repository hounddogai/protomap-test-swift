@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryGlobalFloatPoolManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.GlobalFloatPoolManifestStore = Staffing.newMemoryGlobalFloatPoolManifestStore()
        let item = Staffing.newGlobalFloatPoolManifest("code-765", title: "title-494")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
