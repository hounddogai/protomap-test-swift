import AcmePlatform
import Foundation

extension Labs {
    /// Moves weighted accession mappings through their life cycle and keeps a journal of what it did.
    final class WeightedAccessionMappingDesk {
        var store: any WeightedAccessionMappingStore
        var validator: WeightedAccessionMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedAccessionMappingEngine

        init(store: any WeightedAccessionMappingStore, validator: WeightedAccessionMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedAccessionMappingEngine) {
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
                throw Kit.Failure("weighted accession mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedAccessionMappingStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted accession mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedAccessionMappingStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted accession mapping \(code) not found")
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

    static func newWeightedAccessionMappingDesk(_ store: any WeightedAccessionMappingStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedAccessionMappingDesk {
        return WeightedAccessionMappingDesk(
            store: store,
            validator: defaultWeightedAccessionMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedAccessionMappingEngine(flags)
        )
    }
}
