import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves adaptive interaction records through their life cycle and keeps a journal of what it did.
    final class AdaptiveInteractionRecordDesk {
        var store: any AdaptiveInteractionRecordStore
        var validator: AdaptiveInteractionRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveInteractionRecordEngine

        init(store: any AdaptiveInteractionRecordStore, validator: AdaptiveInteractionRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveInteractionRecordEngine) {
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
                throw Kit.Failure("adaptive interaction record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveInteractionRecordStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive interaction record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveInteractionRecordStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive interaction record \(code) not found")
            }
            let result = engine.run(item)
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

    static func newAdaptiveInteractionRecordDesk(_ store: any AdaptiveInteractionRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveInteractionRecordDesk {
        return AdaptiveInteractionRecordDesk(
            store: store,
            validator: defaultAdaptiveInteractionRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveInteractionRecordEngine(flags)
        )
    }
}
