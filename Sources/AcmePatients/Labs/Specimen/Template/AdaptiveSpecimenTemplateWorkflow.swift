import AcmePlatform
import Foundation

extension Labs {
    /// Moves adaptive specimen templates through their life cycle and keeps a journal of what it did.
    final class AdaptiveSpecimenTemplateService {
        var store: any AdaptiveSpecimenTemplateStore
        var validator: AdaptiveSpecimenTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveSpecimenTemplateEngine

        init(store: any AdaptiveSpecimenTemplateStore, validator: AdaptiveSpecimenTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveSpecimenTemplateEngine) {
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
                throw Kit.Failure("adaptive specimen template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveSpecimenTemplateStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive specimen template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveSpecimenTemplateStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive specimen template \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newAdaptiveSpecimenTemplateService(_ store: any AdaptiveSpecimenTemplateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveSpecimenTemplateService {
        return AdaptiveSpecimenTemplateService(
            store: store,
            validator: defaultAdaptiveSpecimenTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveSpecimenTemplateEngine(flags)
        )
    }
}
