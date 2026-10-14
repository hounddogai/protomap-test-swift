import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal care protocol proposals through their life cycle and keeps a journal of what it did.
    final class SeasonalCareProtocolProposalWorkflow {
        var store: any SeasonalCareProtocolProposalStore
        var validator: SeasonalCareProtocolProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalCareProtocolProposalEngine

        init(store: any SeasonalCareProtocolProposalStore, validator: SeasonalCareProtocolProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalCareProtocolProposalEngine) {
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
                throw Kit.Failure("seasonal care protocol proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCareProtocolProposalStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care protocol proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCareProtocolProposalStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care protocol proposal \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newSeasonalCareProtocolProposalWorkflow(_ store: any SeasonalCareProtocolProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalCareProtocolProposalWorkflow {
        return SeasonalCareProtocolProposalWorkflow(
            store: store,
            validator: defaultSeasonalCareProtocolProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalCareProtocolProposalEngine(flags)
        )
    }
}
