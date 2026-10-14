import AcmePlatform
import Foundation

extension Labs {
    /// Moves tiered reference range records through their life cycle and keeps a journal of what it did.
    final class TieredReferenceRangeRecordCoordinator {
        var store: any TieredReferenceRangeRecordStore
        var validator: TieredReferenceRangeRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredReferenceRangeRecordEngine

        init(store: any TieredReferenceRangeRecordStore, validator: TieredReferenceRangeRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredReferenceRangeRecordEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered reference range record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredReferenceRangeRecordStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered reference range record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredReferenceRangeRecordStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered reference range record \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTieredReferenceRangeRecordCoordinator(_ store: any TieredReferenceRangeRecordStore, clock: any Kit.Clocks.Clock) -> TieredReferenceRangeRecordCoordinator {
        return TieredReferenceRangeRecordCoordinator(
            store: store,
            validator: defaultTieredReferenceRangeRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredReferenceRangeRecordEngine()
        )
    }
}
