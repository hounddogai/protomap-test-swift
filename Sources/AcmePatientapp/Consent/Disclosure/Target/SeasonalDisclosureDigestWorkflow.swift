import AcmePlatform
import Foundation

extension Consent {
    /// Moves seasonal disclosure digests through their life cycle and keeps a journal of what it did.
    final class SeasonalDisclosureDigestWorkflow {
        var store: any SeasonalDisclosureDigestStore
        var validator: SeasonalDisclosureDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalDisclosureDigestEngine

        init(store: any SeasonalDisclosureDigestStore, validator: SeasonalDisclosureDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalDisclosureDigestEngine) {
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
                throw Kit.Failure("seasonal disclosure digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalDisclosureDigestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal disclosure digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalDisclosureDigestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal disclosure digest \(code) not found")
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

    static func newSeasonalDisclosureDigestWorkflow(_ store: any SeasonalDisclosureDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalDisclosureDigestWorkflow {
        return SeasonalDisclosureDigestWorkflow(
            store: store,
            validator: defaultSeasonalDisclosureDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalDisclosureDigestEngine(flags)
        )
    }
}
