import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read agreements through their life cycle and keeps a journal of what it did.
    final class ReadAgreementCoordinator {
        var store: any ReadAgreementStore
        var validator: ReadAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReadAgreementStore, validator: ReadAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadAgreementStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadAgreementStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newReadAgreementCoordinator(_ store: any ReadAgreementStore, clock: any Kit.Clocks.Clock) -> ReadAgreementCoordinator {
        return ReadAgreementCoordinator(
            store: store,
            validator: defaultReadAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
