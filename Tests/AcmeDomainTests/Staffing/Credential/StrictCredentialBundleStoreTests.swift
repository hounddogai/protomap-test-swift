@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictCredentialBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictCredentialBundleStore = Staffing.newMemoryStrictCredentialBundleStore()
        let item = Staffing.newStrictCredentialBundle("code-304", name: "name-670")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
