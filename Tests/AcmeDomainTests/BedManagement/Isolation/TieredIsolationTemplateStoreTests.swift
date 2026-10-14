@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTieredIsolationTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TieredIsolationTemplateStore = BedManagement.newMemoryTieredIsolationTemplateStore()
        let item = BedManagement.newTieredIsolationTemplate("code-203", label: "label-114")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
