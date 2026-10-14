import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential notices through their life cycle and keeps a journal of what it did.
    final class CredentialNoticeManager {
        var store: any CredentialNoticeStore
        var validator: CredentialNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialNoticeEngine

        init(store: any CredentialNoticeStore, validator: CredentialNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialNoticeStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialNoticeStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential notice \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newCredentialNoticeManager(_ store: any CredentialNoticeStore, clock: any Kit.Clocks.Clock) -> CredentialNoticeManager {
        return CredentialNoticeManager(
            store: store,
            validator: defaultCredentialNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialNoticeEngine()
        )
    }
}
