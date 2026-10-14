import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form adjustments through their life cycle and keeps a journal of what it did.
    final class ConsentFormAdjustmentManager {
        var store: any ConsentFormAdjustmentStore
        var validator: ConsentFormAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormAdjustmentEngine

        init(store: any ConsentFormAdjustmentStore, validator: ConsentFormAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormAdjustmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormAdjustmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormAdjustmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form adjustment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newConsentFormAdjustmentManager(_ store: any ConsentFormAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormAdjustmentManager {
        return ConsentFormAdjustmentManager(
            store: store,
            validator: defaultConsentFormAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormAdjustmentEngine(flags)
        )
    }
}
