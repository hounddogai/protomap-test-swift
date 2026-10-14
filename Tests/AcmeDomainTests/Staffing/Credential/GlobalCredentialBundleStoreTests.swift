@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryGlobalCredentialBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.GlobalCredentialBundleStore = Staffing.newMemoryGlobalCredentialBundleStore()
        let item = Staffing.newGlobalCredentialBundle("code-661", name: "name-679")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
