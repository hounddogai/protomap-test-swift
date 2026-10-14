@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLenientDischargePlanWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LenientDischargePlanWindowStore = BedManagement.newMemoryLenientDischargePlanWindowStore()
        let item = BedManagement.newLenientDischargePlanWindow("code-292", name: "name-61")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
