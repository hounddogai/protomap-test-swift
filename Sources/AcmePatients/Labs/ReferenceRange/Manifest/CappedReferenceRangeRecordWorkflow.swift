import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped reference range records through their life cycle and keeps a journal of what it did.
    final class CappedReferenceRangeRecordManager {
        var store: any CappedReferenceRangeRecordStore
        var validator: CappedReferenceRangeRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedReferenceRangeRecordStore, validator: CappedReferenceRangeRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped reference range record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedReferenceRangeRecordStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped reference range record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedReferenceRangeRecordStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newCappedReferenceRangeRecordManager(_ store: any CappedReferenceRangeRecordStore, clock: any Kit.Clocks.Clock) -> CappedReferenceRangeRecordManager {
        return CappedReferenceRangeRecordManager(
            store: store,
            validator: defaultCappedReferenceRangeRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
