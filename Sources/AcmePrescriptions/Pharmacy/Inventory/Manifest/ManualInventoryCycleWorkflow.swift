import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves manual inventory cycles through their life cycle and keeps a journal of what it did.
    final class ManualInventoryCycleDesk {
        var store: any ManualInventoryCycleStore
        var validator: ManualInventoryCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualInventoryCycleEngine

        init(store: any ManualInventoryCycleStore, validator: ManualInventoryCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualInventoryCycleEngine) {
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
                throw Kit.Failure("manual inventory cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualInventoryCycleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual inventory cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualInventoryCycleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual inventory cycle \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newManualInventoryCycleDesk(_ store: any ManualInventoryCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualInventoryCycleDesk {
        return ManualInventoryCycleDesk(
            store: store,
            validator: defaultManualInventoryCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualInventoryCycleEngine(flags)
        )
    }
}
