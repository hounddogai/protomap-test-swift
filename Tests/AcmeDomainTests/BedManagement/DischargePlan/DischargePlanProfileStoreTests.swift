@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanProfileStore = BedManagement.newMemoryDischargePlanProfileStore()
        let item = BedManagement.newDischargePlanProfile("code-473", title: "title-847")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
