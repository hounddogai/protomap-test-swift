@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientOutreachBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientOutreachBundleStore = CareManagement.newMemoryLenientOutreachBundleStore()
        let item = CareManagement.newLenientOutreachBundle("code-20", name: "name-716")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
