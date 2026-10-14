import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation batches through their life cycle and keeps a journal of what it did.
    final class IsolationBatchService {
        var store: any IsolationBatchStore
        var validator: IsolationBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any IsolationBatchStore, validator: IsolationBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("isolation batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationBatchStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationBatchStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newIsolationBatchService(_ store: any IsolationBatchStore, clock: any Kit.Clocks.Clock) -> IsolationBatchService {
        return IsolationBatchService(
            store: store,
            validator: defaultIsolationBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
