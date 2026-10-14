@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackCredentialWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackCredentialWindowStore = Staffing.newMemoryFallbackCredentialWindowStore()
        let item = Staffing.newFallbackCredentialWindow("code-205", label: "label-365")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
