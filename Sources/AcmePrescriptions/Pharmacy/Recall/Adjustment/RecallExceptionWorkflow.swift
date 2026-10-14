import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall exceptions through their life cycle and keeps a journal of what it did.
    final class RecallExceptionCoordinator {
        var store: any RecallExceptionStore
        var validator: RecallExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RecallExceptionStore, validator: RecallExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallExceptionStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallExceptionStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRecallExceptionCoordinator(_ store: any RecallExceptionStore, clock: any Kit.Clocks.Clock) -> RecallExceptionCoordinator {
        return RecallExceptionCoordinator(
            store: store,
            validator: defaultRecallExceptionValidator(),
            clock: clock,
            journal: []
        )
    }
}
