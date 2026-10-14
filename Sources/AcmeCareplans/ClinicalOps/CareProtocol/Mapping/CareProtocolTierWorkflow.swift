import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol tiers through their life cycle and keeps a journal of what it did.
    final class CareProtocolTierDesk {
        var store: any CareProtocolTierStore
        var validator: CareProtocolTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolTierEngine

        init(store: any CareProtocolTierStore, validator: CareProtocolTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolTierEngine) {
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
                throw Kit.Failure("care protocol tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolTierStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolTierStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol tier \(code) not found")
            }
            let result = engine.run(item)
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

    static func newCareProtocolTierDesk(_ store: any CareProtocolTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareProtocolTierDesk {
        return CareProtocolTierDesk(
            store: store,
            validator: defaultCareProtocolTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolTierEngine(flags)
        )
    }
}
