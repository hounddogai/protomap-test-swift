import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range rollups through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeRollupService {
        var store: any ReferenceRangeRollupStore
        var validator: ReferenceRangeRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReferenceRangeRollupStore, validator: ReferenceRangeRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("reference range rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeRollupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeRollupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newReferenceRangeRollupService(_ store: any ReferenceRangeRollupStore, clock: any Kit.Clocks.Clock) -> ReferenceRangeRollupService {
        return ReferenceRangeRollupService(
            store: store,
            validator: defaultReferenceRangeRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
