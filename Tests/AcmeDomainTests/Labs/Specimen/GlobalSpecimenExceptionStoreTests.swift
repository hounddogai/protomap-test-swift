@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalSpecimenExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalSpecimenExceptionStore = Labs.newMemoryGlobalSpecimenExceptionStore()
        let item = Labs.newGlobalSpecimenException("code-699", title: "title-856")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
