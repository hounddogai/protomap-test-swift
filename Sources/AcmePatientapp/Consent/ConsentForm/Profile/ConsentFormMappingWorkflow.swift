import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form mappings through their life cycle and keeps a journal of what it did.
    final class ConsentFormMappingWorkflow {
        var store: any ConsentFormMappingStore
        var validator: ConsentFormMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormMappingEngine

        init(store: any ConsentFormMappingStore, validator: ConsentFormMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormMappingEngine) {
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
                throw Kit.Failure("consent form mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormMappingStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormMappingStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form mapping \(code) not found")
            }
            let result = engine.price(item)
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

    static func newConsentFormMappingWorkflow(_ store: any ConsentFormMappingStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormMappingWorkflow {
        return ConsentFormMappingWorkflow(
            store: store,
            validator: defaultConsentFormMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormMappingEngine(flags)
        )
    }
}
