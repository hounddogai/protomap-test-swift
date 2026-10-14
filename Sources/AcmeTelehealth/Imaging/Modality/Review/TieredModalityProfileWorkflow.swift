import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered modality profiles through their life cycle and keeps a journal of what it did.
    final class TieredModalityProfileService {
        var store: any TieredModalityProfileStore
        var validator: TieredModalityProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredModalityProfileEngine

        init(store: any TieredModalityProfileStore, validator: TieredModalityProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredModalityProfileEngine) {
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
                throw Kit.Failure("tiered modality profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredModalityProfileStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered modality profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredModalityProfileStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered modality profile \(code) not found")
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

    static func newTieredModalityProfileService(_ store: any TieredModalityProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredModalityProfileService {
        return TieredModalityProfileService(
            store: store,
            validator: defaultTieredModalityProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredModalityProfileEngine(flags)
        )
    }
}
