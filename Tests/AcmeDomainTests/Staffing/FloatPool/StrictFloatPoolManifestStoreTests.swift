@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictFloatPoolManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictFloatPoolManifestStore = Staffing.newMemoryStrictFloatPoolManifestStore()
        let item = Staffing.newStrictFloatPoolManifest("code-264", name: "name-390")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
