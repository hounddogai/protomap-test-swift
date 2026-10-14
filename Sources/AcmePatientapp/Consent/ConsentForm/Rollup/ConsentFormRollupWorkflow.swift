import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form rollups through their life cycle and keeps a journal of what it did.
    final class ConsentFormRollupWorkflow {
        var store: any ConsentFormRollupStore
        var validator: ConsentFormRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormRollupEngine

        init(store: any ConsentFormRollupStore, validator: ConsentFormRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormRollupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormRollupStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormRollupStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form rollup \(code) not found")
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

    static func newConsentFormRollupWorkflow(_ store: any ConsentFormRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormRollupWorkflow {
        return ConsentFormRollupWorkflow(
            store: store,
            validator: defaultConsentFormRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormRollupEngine(flags)
        )
    }
}
