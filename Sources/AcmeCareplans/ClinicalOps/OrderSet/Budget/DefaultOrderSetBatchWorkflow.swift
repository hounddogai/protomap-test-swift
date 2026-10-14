import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves default order set batches through their life cycle and keeps a journal of what it did.
    final class DefaultOrderSetBatchService {
        var store: any DefaultOrderSetBatchStore
        var validator: DefaultOrderSetBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultOrderSetBatchStore, validator: DefaultOrderSetBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default order set batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultOrderSetBatchStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default order set batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultOrderSetBatchStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newDefaultOrderSetBatchService(_ store: any DefaultOrderSetBatchStore, clock: any Kit.Clocks.Clock) -> DefaultOrderSetBatchService {
        return DefaultOrderSetBatchService(
            store: store,
            validator: defaultDefaultOrderSetBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
