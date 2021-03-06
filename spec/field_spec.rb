require 'spec_helper'

RSpec.describe Formwandler::Field do
  let(:field_name) { :my_field }
  let(:model_field_type) { double }
  let(:model_class) { double('ActiveRecord::Base', attribute_types: {field_name.to_s => model_field_type}, my_fields: {option1: 0, option2: 1, option3: 2}) }
  let(:model_instance) { double(class: model_class) }
  let(:model) { nil }
  let(:form) { double('Formwandler::Form', models: {model => model_instance}) }
  let(:field_definition_params) { {name: field_name, model: model} }
  let(:field_definition) { double('Formwandler::FieldDefinition', field_definition_params) }
  let(:field) { described_class.new(form: form, field_definition: field_definition) }

  describe '#options' do
    let(:hidden_options) { {} }
    let(:field_definition_params) { super().merge(options: options, hidden_options: hidden_options) }

    subject { field.options }

    shared_context 'model field type is enum' do |flag|
      before(:each) do
        allow(model_field_type).to receive(:is_a?).with(ActiveRecord::Enum::EnumType).and_return(flag)
      end
    end

    before(:each) do
      allow(model_instance).to receive(:is_a?).with(ActiveRecord::Base).and_return(true)
    end

    context 'when the field_definition has no options' do
      let(:options) { nil }

      context 'and no model' do
        let(:model) { nil }

        it { is_expected.to eq([]) }
      end

      context 'but a model' do
        let(:model) { :my_model }

        context 'and the field name is a defined enum' do
          include_context 'model field type is enum', true

          let(:enum_mapping) { {'option1' => 0, 'option2' => 1, 'option3' => 2}.with_indifferent_access }

          before(:each) do
            allow(model_class).to receive(field_name.to_s.pluralize).and_return(enum_mapping)
          end

          it { is_expected.to eq(['option1', 'option2', 'option3']) }

          context 'and an option has been hidden' do
            let(:hidden_options) { super().merge('option2' => true) }

            it { is_expected.to eq(['option1', 'option3']) }
          end
        end

        context 'and the field name is no defined enum' do
          include_context 'model field type is enum', false

          it { is_expected.to eq([]) }
        end
      end
    end
  end

  describe '#readonly?' do
    let(:field_definition_params) { super().merge(readonly: readonly_value) }

    subject { field.readonly? }

    context 'when the readonly value is' do
      context 'false' do
        let(:readonly_value) { false }

        it { is_expected.to eq(false) }
      end

      context 'true' do
        let(:readonly_value) { true }

        it { is_expected.to eq(true) }
      end

      context 'a proc' do
        let(:readonly_value) { -> { readonly_proc_value } }

        before(:each) do
          expect(form).to receive(:readonly_proc_value).and_return(readonly_proc_value)
        end

        context 'that evaluates to true' do
          let(:readonly_proc_value) { true }

          it { is_expected.to eq(true) }
        end

        context 'that evaluates to false' do
          let(:readonly_proc_value) { false }

          it { is_expected.to eq(false) }
        end
      end
    end
  end
end
